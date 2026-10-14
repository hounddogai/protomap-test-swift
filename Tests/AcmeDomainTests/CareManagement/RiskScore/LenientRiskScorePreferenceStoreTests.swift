@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientRiskScorePreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientRiskScorePreferenceStore = CareManagement.newMemoryLenientRiskScorePreferenceStore()
        let item = CareManagement.newLenientRiskScorePreference("code-880", title: "title-78")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
