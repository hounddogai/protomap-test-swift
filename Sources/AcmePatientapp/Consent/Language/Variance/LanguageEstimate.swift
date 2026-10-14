import AcmePlatform
import Foundation

extension Consent {
    /// Where a language estimate is in its life cycle.
    enum LanguageEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a language estimate and its current status.
    final class LanguageEstimate {
        var code: String
        var title: String
        var facility: String
        var discount: Double
        var revision: Int
        var source: String
        var allergy: String
        var attributes: [String: String]
        var visible: Bool
        var retries: Int
        var status: LanguageEstimateStatus

        init(code: String, title: String, facility: String, discount: Double, revision: Int, source: String, allergy: String, attributes: [String: String], visible: Bool, retries: Int, status: LanguageEstimateStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.discount = discount
            self.revision = revision
            self.source = source
            self.allergy = allergy
            self.attributes = attributes
            self.visible = visible
            self.retries = retries
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

        func canMoveTo(_ next: LanguageEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == LanguageEstimateStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: LanguageEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
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
            return ((Double(retries) + discount) * 100).rounded() / 100
        }

        func copyValue() -> LanguageEstimate {
            return LanguageEstimate(
                code: code,
                title: title,
                facility: facility,
                discount: discount,
                revision: revision,
                source: source,
                allergy: allergy,
                attributes: attributes,
                visible: visible,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a language estimate in status new.
    static func newLanguageEstimate(_ code: String, title: String) -> LanguageEstimate {
        return LanguageEstimate(
            code: code,
            title: title,
            facility: "",
            discount: 0.0,
            revision: 0,
            source: "",
            allergy: "",
            attributes: [:],
            visible: false,
            retries: 0,
            status: LanguageEstimateStatus.new
        )
    }
}
