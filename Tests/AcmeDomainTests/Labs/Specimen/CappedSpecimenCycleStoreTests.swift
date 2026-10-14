@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedSpecimenCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedSpecimenCycleStore = Labs.newMemoryCappedSpecimenCycleStore()
        let item = Labs.newCappedSpecimenCycle("code-408", title: "title-565")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
