@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolOverrideStore = Staffing.newMemoryFloatPoolOverrideStore()
        let item = Staffing.newFloatPoolOverride("code-63", name: "name-265")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
