@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentLedgerStore = CareManagement.newMemoryAssessmentLedgerStore()
        let item = CareManagement.newAssessmentLedger("code-870", name: "name-176")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
