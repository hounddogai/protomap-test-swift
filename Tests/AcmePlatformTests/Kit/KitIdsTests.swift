import AcmePlatform
import Foundation
import Testing

@Suite struct KitIDsTests {
    @Test func padsSequenceNumbers() throws {
        #expect(Kit.IDs.newID("inv", seq: 42) == "INV-000042")
        #expect(Kit.IDs.isReference("INV-000042", prefix: "inv"))
    }
}
