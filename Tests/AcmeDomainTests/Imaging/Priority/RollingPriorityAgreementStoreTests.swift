@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRollingPriorityAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RollingPriorityAgreementStore = Imaging.newMemoryRollingPriorityAgreementStore()
        let item = Imaging.newRollingPriorityAgreement("code-755", title: "title-462")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
