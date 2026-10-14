@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryRollingDischargePlanScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.RollingDischargePlanScoreStore = BedManagement.newMemoryRollingDischargePlanScoreStore()
        let item = BedManagement.newRollingDischargePlanScore("code-451", title: "title-363")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
