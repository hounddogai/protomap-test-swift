import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan quota is in its life cycle.
    enum AcuityPlanQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A acuity plan quota. Its code is unique within a tenant.
    final class AcuityPlanQuota {
        var code: String
        var name: String
        var reviewer: String
        var source: String
        var minimum: Double
        var summary: String
        var attributes: [String: String]
        var threshold: Double
        var endsAt: Int
        var description: String
        var status: AcuityPlanQuotaStatus

        init(code: String, name: String, reviewer: String, source: String, minimum: Double, summary: String, attributes: [String: String], threshold: Double, endsAt: Int, description: String, status: AcuityPlanQuotaStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.source = source
            self.minimum = minimum
            self.summary = summary
            self.attributes = attributes
            self.threshold = threshold
            self.endsAt = endsAt
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AcuityPlanQuotaStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AcuityPlanQuotaStatus.done || next == AcuityPlanQuotaStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AcuityPlanQuotaStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func adjustedValue() -> Double {
            return ((minimum + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanQuota {
            return AcuityPlanQuota(
                code: code,
                name: name,
                reviewer: reviewer,
                source: source,
                minimum: minimum,
                summary: summary,
                attributes: attributes,
                threshold: threshold,
                endsAt: endsAt,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a acuity plan quota in status new.
    static func newAcuityPlanQuota(_ code: String, name: String) -> AcuityPlanQuota {
        return AcuityPlanQuota(
            code: code,
            name: name,
            reviewer: "",
            source: "",
            minimum: 0.0,
            summary: "",
            attributes: [:],
            threshold: 0.0,
            endsAt: 0,
            description: "",
            status: AcuityPlanQuotaStatus.new
        )
    }
}
