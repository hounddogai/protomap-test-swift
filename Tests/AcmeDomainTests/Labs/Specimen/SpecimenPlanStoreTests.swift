@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenPlanStore = Labs.newMemorySpecimenPlanStore()
        let item = Labs.newSpecimenPlan("code-406", label: "label-157")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
