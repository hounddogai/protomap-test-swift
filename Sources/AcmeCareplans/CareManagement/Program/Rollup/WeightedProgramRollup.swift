import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted program rollup is in its life cycle.
    enum WeightedProgramRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted program rollup. Its code is unique within a tenant.
    final class WeightedProgramRollup {
        var code: String
        var label: String
        var bed: String
        var region: String
        var pinned: Bool
        var attributes: [String: String]
        var updatedAt: Int
        var title: String
        var diagnosisCode: String
        var payer: String
        var segment: String
        var status: WeightedProgramRollupStatus

        init(code: String, label: String, bed: String, region: String, pinned: Bool, attributes: [String: String], updatedAt: Int, title: String, diagnosisCode: String, payer: String, segment: String, status: WeightedProgramRollupStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.region = region
            self.pinned = pinned
            self.attributes = attributes
            self.updatedAt = updatedAt
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.payer = payer
            self.segment = segment
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

        func canMoveTo(_ next: WeightedProgramRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedProgramRollupStatus.running || next == WeightedProgramRollupStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: WeightedProgramRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted program rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> WeightedProgramRollup {
            return WeightedProgramRollup(
                code: code,
                label: label,
                bed: bed,
                region: region,
                pinned: pinned,
                attributes: attributes,
                updatedAt: updatedAt,
                title: title,
                diagnosisCode: diagnosisCode,
                payer: payer,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted program rollup in status new.
    static func newWeightedProgramRollup(_ code: String, label: String) -> WeightedProgramRollup {
        return WeightedProgramRollup(
            code: code,
            label: label,
            bed: "",
            region: "",
            pinned: false,
            attributes: [:],
            updatedAt: 0,
            title: "",
            diagnosisCode: "",
            payer: "",
            segment: "",
            status: WeightedProgramRollupStatus.new
        )
    }
}
