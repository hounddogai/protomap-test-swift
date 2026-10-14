@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryWeightedFloatPoolTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.WeightedFloatPoolTemplateStore = Staffing.newMemoryWeightedFloatPoolTemplateStore()
        let item = Staffing.newWeightedFloatPoolTemplate("code-437", name: "name-519")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
