@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingAssignmentStore = ClinicalOps.newMemoryRoundingAssignmentStore()
        let item = ClinicalOps.newRoundingAssignment("code-545", name: "name-823")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
