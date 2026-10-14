@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryStrictSpecimenPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.StrictSpecimenPlanStore = Labs.newMemoryStrictSpecimenPlanStore()
        let item = Labs.newStrictSpecimenPlan("code-543", label: "label-212")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
