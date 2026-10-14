@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingSpecimenCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingSpecimenCycleStore = Labs.newMemoryPendingSpecimenCycleStore()
        let item = Labs.newPendingSpecimenCycle("code-604", label: "label-545")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
