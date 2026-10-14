@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialSummaryStore = Staffing.newMemoryCredentialSummaryStore()
        let item = Staffing.newCredentialSummary("code-342", name: "name-508")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
