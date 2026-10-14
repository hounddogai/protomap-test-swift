import AcmePlatform
import Foundation

extension Labs {
    /// Where a default result score is in its life cycle.
    enum DefaultResultScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a default result score and its current status.
    final class DefaultResultScore {
        var code: String
        var name: String
        var country: String
        var summary: String
        var locale: String
        var budget: Double
        var procedureCode: String
        var quantity: Int
        var acuity: Int
        var status: DefaultResultScoreStatus

        init(code: String, name: String, country: String, summary: String, locale: String, budget: Double, procedureCode: String, quantity: Int, acuity: Int, status: DefaultResultScoreStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.summary = summary
            self.locale = locale
            self.budget = budget
            self.procedureCode = procedureCode
            self.quantity = quantity
            self.acuity = acuity
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

        func canMoveTo(_ next: DefaultResultScoreStatus) -> Bool {
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
                return next == DefaultResultScoreStatus.failed
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

        func moveTo(_ next: DefaultResultScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default result score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedValue() -> Double {
            return ((budget + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultResultScore {
            return DefaultResultScore(
                code: code,
                name: name,
                country: country,
                summary: summary,
                locale: locale,
                budget: budget,
                procedureCode: procedureCode,
                quantity: quantity,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default result score in status new.
    static func newDefaultResultScore(_ code: String, name: String) -> DefaultResultScore {
        return DefaultResultScore(
            code: code,
            name: name,
            country: "",
            summary: "",
            locale: "",
            budget: 0.0,
            procedureCode: "",
            quantity: 0,
            acuity: 0,
            status: DefaultResultScoreStatus.new
        )
    }
}
