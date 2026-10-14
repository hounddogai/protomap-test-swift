@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultSpecimenPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultSpecimenPlanStore = Labs.newMemoryDefaultSpecimenPlanStore()
        let item = Labs.newDefaultSpecimenPlan("code-206", title: "title-674")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
