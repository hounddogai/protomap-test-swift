@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialRuleStore = Staffing.newMemoryCredentialRuleStore()
        let item = Staffing.newCredentialRule("code-624", title: "title-253")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
