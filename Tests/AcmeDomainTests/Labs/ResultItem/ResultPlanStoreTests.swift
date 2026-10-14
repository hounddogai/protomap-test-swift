@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultPlanStore = Labs.newMemoryResultPlanStore()
        let item = Labs.newResultPlan("code-447", name: "name-740")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
