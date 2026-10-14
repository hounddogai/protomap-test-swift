import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network entry is in its life cycle.
    enum NetworkEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A network entry. Its code is unique within a tenant.
    final class NetworkEntry {
        var code: String
        var name: String
        var source: String
        var title: String
        var phone: String
        var diagnosisCode: String
        var ownerID: String
        var category: String
        var score: Double
        var region: String
        var endsAt: Int
        var status: NetworkEntryStatus

        init(code: String, name: String, source: String, title: String, phone: String, diagnosisCode: String, ownerID: String, category: String, score: Double, region: String, endsAt: Int, status: NetworkEntryStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.title = title
            self.phone = phone
            self.diagnosisCode = diagnosisCode
            self.ownerID = ownerID
            self.category = category
            self.score = score
            self.region = region
            self.endsAt = endsAt
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

        func canMoveTo(_ next: NetworkEntryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == NetworkEntryStatus.done
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: NetworkEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("network entry") \(code)"
        }

        func projectedTotal() -> Double {
            return ((score - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkEntry {
            return NetworkEntry(
                code: code,
                name: name,
                source: source,
                title: title,
                phone: phone,
                diagnosisCode: diagnosisCode,
                ownerID: ownerID,
                category: category,
                score: score,
                region: region,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a network entry in status new.
    static func newNetworkEntry(_ code: String, name: String) -> NetworkEntry {
        return NetworkEntry(
            code: code,
            name: name,
            source: "",
            title: "",
            phone: "",
            diagnosisCode: "",
            ownerID: "",
            category: "",
            score: 0.0,
            region: "",
            endsAt: 0,
            status: NetworkEntryStatus.new
        )
    }
}
