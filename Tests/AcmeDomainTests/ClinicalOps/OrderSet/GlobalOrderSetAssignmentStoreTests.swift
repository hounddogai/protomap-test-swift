@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalOrderSetAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalOrderSetAssignmentStore = ClinicalOps.newMemoryGlobalOrderSetAssignmentStore()
        let item = ClinicalOps.newGlobalOrderSetAssignment("code-206", name: "name-713")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
