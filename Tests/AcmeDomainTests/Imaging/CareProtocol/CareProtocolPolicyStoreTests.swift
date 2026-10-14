@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolPolicyStore = Imaging.newMemoryCareProtocolPolicyStore()
        let item = Imaging.newCareProtocolPolicy("code-650", name: "name-903")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
