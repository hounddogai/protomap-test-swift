@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryScheduledAccessionTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ScheduledAccessionTargetStore = Labs.newMemoryScheduledAccessionTargetStore()
        let item = Labs.newScheduledAccessionTarget("code-30", label: "label-600")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
