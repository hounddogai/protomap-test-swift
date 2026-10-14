import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement template is in its life cycle.
    enum StatementTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One statement template, with what the planners need to act on it.
    final class StatementTemplate {
        var code: String
        var name: String
        var score: Double
        var rate: Double
        var priority: Int
        var locale: String
        var specialty: String
        var summary: String
        var attributes: [String: String]
        var limit: Int
        var phone: String
        var status: StatementTemplateStatus

        init(code: String, name: String, score: Double, rate: Double, priority: Int, locale: String, specialty: String, summary: String, attributes: [String: String], limit: Int, phone: String, status: StatementTemplateStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.rate = rate
            self.priority = priority
            self.locale = locale
            self.specialty = specialty
            self.summary = summary
            self.attributes = attributes
            self.limit = limit
            self.phone = phone
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

        func canMoveTo(_ next: StatementTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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
                return next == StatementTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func weightedVolume() -> Double {
            return ((Double(limit) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> StatementTemplate {
            return StatementTemplate(
                code: code,
                name: name,
                score: score,
                rate: rate,
                priority: priority,
                locale: locale,
                specialty: specialty,
                summary: summary,
                attributes: attributes,
                limit: limit,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a statement template in status new.
    static func newStatementTemplate(_ code: String, name: String) -> StatementTemplate {
        return StatementTemplate(
            code: code,
            name: name,
            score: 0.0,
            rate: 0.0,
            priority: 0,
            locale: "",
            specialty: "",
            summary: "",
            attributes: [:],
            limit: 0,
            phone: "",
            status: StatementTemplateStatus.new
        )
    }
}
