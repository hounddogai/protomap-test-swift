@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackCareProtocolAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackCareProtocolAssignmentStore = ClinicalOps.newMemoryFallbackCareProtocolAssignmentStore()
        let item = ClinicalOps.newFallbackCareProtocolAssignment("code-752", label: "label-614")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
