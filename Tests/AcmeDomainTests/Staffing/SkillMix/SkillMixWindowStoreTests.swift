@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixWindowStore = Staffing.newMemorySkillMixWindowStore()
        let item = Staffing.newSkillMixWindow("code-963", title: "title-468")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
