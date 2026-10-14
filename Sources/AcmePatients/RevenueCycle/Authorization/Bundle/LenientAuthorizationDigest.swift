import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient authorization digest is in its life cycle.
    enum LenientAuthorizationDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient authorization digest and its current status.
    final class LenientAuthorizationDigest {
        var code: String
        var label: String
        var quantity: Int
        var batchSize: Int
        var expiresAt: Int
        var patientRef: String
        var name: String
        var limit: Int
        var title: String
        var status: LenientAuthorizationDigestStatus

        init(code: String, label: String, quantity: Int, batchSize: Int, expiresAt: Int, patientRef: String, name: String, limit: Int, title: String, status: LenientAuthorizationDigestStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.batchSize = batchSize
            self.expiresAt = expiresAt
            self.patientRef = patientRef
            self.name = name
            self.limit = limit
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientAuthorizationDigestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientAuthorizationDigestStatus.resolved || next == LenientAuthorizationDigestStatus.reopened
            case .inReview:
                return next == LenientAuthorizationDigestStatus.resolved || next == LenientAuthorizationDigestStatus.archived
            case .resolved:
                return next == LenientAuthorizationDigestStatus.reopened
            case .reopened:
                return next == LenientAuthorizationDigestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientAuthorizationDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient authorization digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return (Double(expiresAt) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> LenientAuthorizationDigest {
            return LenientAuthorizationDigest(
                code: code,
                label: label,
                quantity: quantity,
                batchSize: batchSize,
                expiresAt: expiresAt,
                patientRef: patientRef,
                name: name,
                limit: limit,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient authorization digest in status open.
    static func newLenientAuthorizationDigest(_ code: String, label: String) -> LenientAuthorizationDigest {
        return LenientAuthorizationDigest(
            code: code,
            label: label,
            quantity: 0,
            batchSize: 0,
            expiresAt: 0,
            patientRef: "",
            name: "",
            limit: 0,
            title: "",
            status: LenientAuthorizationDigestStatus.`open`
        )
    }
}
