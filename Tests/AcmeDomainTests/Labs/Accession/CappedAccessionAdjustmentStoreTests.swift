@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedAccessionAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedAccessionAdjustmentStore = Labs.newMemoryCappedAccessionAdjustmentStore()
        let item = Labs.newCappedAccessionAdjustment("code-802", label: "label-90")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
