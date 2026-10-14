@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixMetricStore = Staffing.newMemorySkillMixMetricStore()
        let item = Staffing.newSkillMixMetric("code-4", title: "title-999")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
