import AcmePlatform
import Foundation

extension Consent {
    /// Where a language score is in its life cycle.
    enum LanguageScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a language score and its current status.
    final class LanguageScore {
        var code: String
        var name: String
        var maximum: Double
        var createdAt: Int
        var label: String
        var dosageMg: Double
        var copay: Double
        var locale: String
        var minimum: Double
        var specialty: String
        var batchSize: Int
        var status: LanguageScoreStatus

        init(code: String, name: String, maximum: Double, createdAt: Int, label: String, dosageMg: Double, copay: Double, locale: String, minimum: Double, specialty: String, batchSize: Int, status: LanguageScoreStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.createdAt = createdAt
            self.label = label
            self.dosageMg = dosageMg
            self.copay = copay
            self.locale = locale
            self.minimum = minimum
            self.specialty = specialty
            self.batchSize = batchSize
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

        func canMoveTo(_ next: LanguageScoreStatus) -> Bool {
            switch status {
            case .new:
                return next == LanguageScoreStatus.running
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
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LanguageScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return ((Double(batchSize) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> LanguageScore {
            return LanguageScore(
                code: code,
                name: name,
                maximum: maximum,
                createdAt: createdAt,
                label: label,
                dosageMg: dosageMg,
                copay: copay,
                locale: locale,
                minimum: minimum,
                specialty: specialty,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a language score in status new.
    static func newLanguageScore(_ code: String, name: String) -> LanguageScore {
        return LanguageScore(
            code: code,
            name: name,
            maximum: 0.0,
            createdAt: 0,
            label: "",
            dosageMg: 0.0,
            copay: 0.0,
            locale: "",
            minimum: 0.0,
            specialty: "",
            batchSize: 0,
            status: LanguageScoreStatus.new
        )
    }
}
