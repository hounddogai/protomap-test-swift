import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read digest is in its life cycle.
    enum ReadDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a read digest and its current status.
    final class ReadDigest {
        var code: String
        var name: String
        var procedureCode: String
        var attributes: [String: String]
        var rate: Double
        var status: ReadDigestStatus

        init(code: String, name: String, procedureCode: String, attributes: [String: String], rate: Double, status: ReadDigestStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.attributes = attributes
            self.rate = rate
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

        func canMoveTo(_ next: ReadDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == ReadDigestStatus.running || next == ReadDigestStatus.done
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

        func moveTo(_ next: ReadDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
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
            return rate
        }

        func copyValue() -> ReadDigest {
            return ReadDigest(
                code: code,
                name: name,
                procedureCode: procedureCode,
                attributes: attributes,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a read digest in status new.
    static func newReadDigest(_ code: String, name: String) -> ReadDigest {
        return ReadDigest(
            code: code,
            name: name,
            procedureCode: "",
            attributes: [:],
            rate: 0.0,
            status: ReadDigestStatus.new
        )
    }
}
