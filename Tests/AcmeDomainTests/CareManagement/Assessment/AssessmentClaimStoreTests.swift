@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentClaimStore = CareManagement.newMemoryAssessmentClaimStore()
        let item = CareManagement.newAssessmentClaim("code-800", label: "label-717")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
