@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixMappingStore = Staffing.newMemorySkillMixMappingStore()
        let item = Staffing.newSkillMixMapping("code-988", label: "label-662")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
