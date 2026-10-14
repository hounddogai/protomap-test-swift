import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched disclosure request is in its life cycle.
    enum BatchedDisclosureRequestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a batched disclosure request and its current status.
    final class BatchedDisclosureRequest {
        var code: String
        var title: String
        var reviewer: String
        var durationMinutes: Int
        var retries: Int
        var expiresAt: Int
        var specialty: String
        var segment: String
        var copay: Double
        var attributes: [String: String]
        var budget: Double
        var status: BatchedDisclosureRequestStatus

        init(code: String, title: String, reviewer: String, durationMinutes: Int, retries: Int, expiresAt: Int, specialty: String, segment: String, copay: Double, attributes: [String: String], budget: Double, status: BatchedDisclosureRequestStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.retries = retries
            self.expiresAt = expiresAt
            self.specialty = specialty
            self.segment = segment
            self.copay = copay
            self.attributes = attributes
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedDisclosureRequestStatus) -> Bool {
            switch status {
            case .requested:
                return next == BatchedDisclosureRequestStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == BatchedDisclosureRequestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedDisclosureRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched disclosure request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("batched disclosure request") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((Double(durationMinutes) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDisclosureRequest {
            return BatchedDisclosureRequest(
                code: code,
                title: title,
                reviewer: reviewer,
                durationMinutes: durationMinutes,
                retries: retries,
                expiresAt: expiresAt,
                specialty: specialty,
                segment: segment,
                copay: copay,
                attributes: attributes,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched disclosure request in status requested.
    static func newBatchedDisclosureRequest(_ code: String, title: String) -> BatchedDisclosureRequest {
        return BatchedDisclosureRequest(
            code: code,
            title: title,
            reviewer: "",
            durationMinutes: 0,
            retries: 0,
            expiresAt: 0,
            specialty: "",
            segment: "",
            copay: 0.0,
            attributes: [:],
            budget: 0.0,
            status: BatchedDisclosureRequestStatus.requested
        )
    }
}
