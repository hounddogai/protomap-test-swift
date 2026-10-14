@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedCareGapClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedCareGapClaimStore = CareManagement.newMemoryCappedCareGapClaimStore()
        let item = CareManagement.newCappedCareGapClaim("code-401", label: "label-306")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
