@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeSlotStore = Labs.newMemoryReferenceRangeSlotStore()
        let item = Labs.newReferenceRangeSlot("code-932", label: "label-509")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
