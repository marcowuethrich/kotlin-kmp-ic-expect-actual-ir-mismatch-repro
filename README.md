# EXPECT_ACTUAL_IR_MISMATCH with incremental compilation of common sources (Kotlin 2.5)

With `kotlin.jvm.enableIncrementalCompilationOfCommonSources=true`, a body-only edit of a common file
that uses an `object` only as a qualifier (`Holder.name`) makes the next incremental `compileKotlinJvm`
fail on another member of that object, in a file nobody edited. Every following build fails the same
way until a non-incremental one.

```kotlin
// src/commonMain/kotlin/Holder.kt
class A

object Holder {
    val name: String get() = "holder"

    fun select(x: A): String = "select"
}

// src/commonMain/kotlin/Greeting.kt: the only file edited
fun greeting(): String = "Hello, " + Holder.name
```

## Steps

1. `./gradlew compileKotlinJvm`
2. Change only the body of `greeting()`, for example to `"Hello, " + Holder.name + "!"`.
3. `./gradlew compileKotlinJvm`
4. `./gradlew compileKotlinJvm` again, without any change.

`./repro.sh` runs these steps, then a build with `--rerun-tasks`, and restores `Greeting.kt`.

**Expected:** builds 3 and 4 recompile `Greeting.kt` and pass.

**Actual:** both fail; `--rerun-tasks` passes.

```
e: The 'actual' declaration 'repro.Holder.select' from '<commonMain> for JVM' doesn't match the 'actual' declaration 'repro.Holder.select' from '<repro> for JVM' because parameter types are different.
```

**Workaround:** add `kotlin.internal.jvm.enableKmpClasspathMetadataForIncrementalCompilation=false`
to `gradle.properties`.

Reproduces with Kotlin 2.5.0-Beta2 (this build) and 2.5.20-dev-2678, Gradle 9.8.2, JDK 25, macOS
arm64. Kotlin 2.4.21 with the equivalent `kotlin.internal.*` properties is not affected.
