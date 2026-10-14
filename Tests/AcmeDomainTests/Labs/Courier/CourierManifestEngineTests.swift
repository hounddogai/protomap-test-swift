@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierManifestEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierManifest("code-254", title: "title-272")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
