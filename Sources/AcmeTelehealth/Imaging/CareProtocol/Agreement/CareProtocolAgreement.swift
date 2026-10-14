import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol agreement is in its life cycle.
    enum CareProtocolAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One care protocol agreement, with what the planners need to act on it.
    final class CareProtocolAgreement {
        var code: String
        var title: String
        var bed: String
        var ratio: Double
        var pinned: Bool
        var cost: Double
        var ward: String
        var capacity: Int
        var updatedAt: Int
        var tags: [String]
        var externalRef: String
        var status: CareProtocolAgreementStatus

        init(code: String, title: String, bed: String, ratio: Double, pinned: Bool, cost: Double, ward: String, capacity: Int, updatedAt: Int, tags: [String], externalRef: String, status: CareProtocolAgreementStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.ratio = ratio
            self.pinned = pinned
            self.cost = cost
            self.ward = ward
            self.capacity = capacity
            self.updatedAt = updatedAt
            self.tags = tags
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolAgreementStatus) -> Bool {
            switch status {
            case .created:
                return next == CareProtocolAgreementStatus.validated || next == CareProtocolAgreementStatus.retired
            case .validated:
                return next == CareProtocolAgreementStatus.published
            case .published:
                return next == CareProtocolAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("care protocol agreement") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return (Double(capacity) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolAgreement {
            return CareProtocolAgreement(
                code: code,
                title: title,
                bed: bed,
                ratio: ratio,
                pinned: pinned,
                cost: cost,
                ward: ward,
                capacity: capacity,
                updatedAt: updatedAt,
                tags: tags,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a care protocol agreement in status created.
    static func newCareProtocolAgreement(_ code: String, title: String) -> CareProtocolAgreement {
        return CareProtocolAgreement(
            code: code,
            title: title,
            bed: "",
            ratio: 0.0,
            pinned: false,
            cost: 0.0,
            ward: "",
            capacity: 0,
            updatedAt: 0,
            tags: [],
            externalRef: "",
            status: CareProtocolAgreementStatus.created
        )
    }
}
