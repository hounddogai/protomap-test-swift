@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemorySeasonalTransferPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.SeasonalTransferPolicyStore = BedManagement.newMemorySeasonalTransferPolicyStore()
        let item = BedManagement.newSeasonalTransferPolicy("code-856", name: "name-218")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
