import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global formulary baseline is in its life cycle.
    enum GlobalFormularyBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One global formulary baseline, with what the planners need to act on it.
    final class GlobalFormularyBaseline {
        var code: String
        var label: String
        var category: String
        var threshold: Double
        var visible: Bool
        var clinicianID: String
        var attributes: [String: String]
        var weight: Double
        var active: Bool
        var status: GlobalFormularyBaselineStatus

        init(code: String, label: String, category: String, threshold: Double, visible: Bool, clinicianID: String, attributes: [String: String], weight: Double, active: Bool, status: GlobalFormularyBaselineStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.threshold = threshold
            self.visible = visible
            self.clinicianID = clinicianID
            self.attributes = attributes
            self.weight = weight
            self.active = active
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

        func canMoveTo(_ next: GlobalFormularyBaselineStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalFormularyBaselineStatus.done
            case .queued:
                return next == GlobalFormularyBaselineStatus.done || next == GlobalFormularyBaselineStatus.failed
            case .running:
                return next == GlobalFormularyBaselineStatus.done
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

        func moveTo(_ next: GlobalFormularyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global formulary baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global formulary baseline") \(code)"
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

        func adjustedTotal() -> Double {
            return ((threshold + weight) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFormularyBaseline {
            return GlobalFormularyBaseline(
                code: code,
                label: label,
                category: category,
                threshold: threshold,
                visible: visible,
                clinicianID: clinicianID,
                attributes: attributes,
                weight: weight,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a global formulary baseline in status new.
    static func newGlobalFormularyBaseline(_ code: String, label: String) -> GlobalFormularyBaseline {
        return GlobalFormularyBaseline(
            code: code,
            label: label,
            category: "",
            threshold: 0.0,
            visible: false,
            clinicianID: "",
            attributes: [:],
            weight: 0.0,
            active: false,
            status: GlobalFormularyBaselineStatus.new
        )
    }
}
