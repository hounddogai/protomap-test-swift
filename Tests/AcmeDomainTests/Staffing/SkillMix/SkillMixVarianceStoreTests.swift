@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixVarianceStore = Staffing.newMemorySkillMixVarianceStore()
        let item = Staffing.newSkillMixVariance("code-103", name: "name-588")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
