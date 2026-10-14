@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionPlanStore = Labs.newMemoryAccessionPlanStore()
        let item = Labs.newAccessionPlan("code-13", title: "title-985")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
