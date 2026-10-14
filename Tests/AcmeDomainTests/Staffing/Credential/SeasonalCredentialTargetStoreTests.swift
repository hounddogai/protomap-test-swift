@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySeasonalCredentialTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SeasonalCredentialTargetStore = Staffing.newMemorySeasonalCredentialTargetStore()
        let item = Staffing.newSeasonalCredentialTarget("code-108", name: "name-465")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
