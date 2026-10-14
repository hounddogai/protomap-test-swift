@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixAgreementStore = Staffing.newMemorySkillMixAgreementStore()
        let item = Staffing.newSkillMixAgreement("code-8", title: "title-648")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
