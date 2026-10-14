@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryDefaultFloatPoolClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.DefaultFloatPoolClaimStore = Staffing.newMemoryDefaultFloatPoolClaimStore()
        let item = Staffing.newDefaultFloatPoolClaim("code-246", label: "label-750")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
