import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched proxy override is in its life cycle.
    enum BatchedProxyOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched proxy override. Its code is unique within a tenant.
    final class BatchedProxyOverride {
        var code: String
        var label: String
        var externalRef: String
        var facility: String
        var startsAt: Int
        var dosageMg: Double
        var patientRef: String
        var margin: Double
        var retries: Int
        var attributes: [String: String]
        var rate: Double
        var status: BatchedProxyOverrideStatus

        init(code: String, label: String, externalRef: String, facility: String, startsAt: Int, dosageMg: Double, patientRef: String, margin: Double, retries: Int, attributes: [String: String], rate: Double, status: BatchedProxyOverrideStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.facility = facility
            self.startsAt = startsAt
            self.dosageMg = dosageMg
            self.patientRef = patientRef
            self.margin = margin
            self.retries = retries
            self.attributes = attributes
            self.rate = rate
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

        func canMoveTo(_ next: BatchedProxyOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BatchedProxyOverrideStatus.inReview || next == BatchedProxyOverrideStatus.archived
            case .inReview:
                return next == BatchedProxyOverrideStatus.resolved
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedProxyOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched proxy override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func weightedValue() -> Double {
            return ((margin - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedProxyOverride {
            return BatchedProxyOverride(
                code: code,
                label: label,
                externalRef: externalRef,
                facility: facility,
                startsAt: startsAt,
                dosageMg: dosageMg,
                patientRef: patientRef,
                margin: margin,
                retries: retries,
                attributes: attributes,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a batched proxy override in status open.
    static func newBatchedProxyOverride(_ code: String, label: String) -> BatchedProxyOverride {
        return BatchedProxyOverride(
            code: code,
            label: label,
            externalRef: "",
            facility: "",
            startsAt: 0,
            dosageMg: 0.0,
            patientRef: "",
            margin: 0.0,
            retries: 0,
            attributes: [:],
            rate: 0.0,
            status: BatchedProxyOverrideStatus.`open`
        )
    }
}
