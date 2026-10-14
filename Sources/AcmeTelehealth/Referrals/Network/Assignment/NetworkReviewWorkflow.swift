import AcmePlatform
import Foundation

extension Referrals {
    /// Moves network reviews through their life cycle and keeps a journal of what it did.
    final class NetworkReviewService {
        var store: any NetworkReviewStore
        var validator: NetworkReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: NetworkReviewEngine

        init(store: any NetworkReviewStore, validator: NetworkReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: NetworkReviewEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(NetworkReviewStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(NetworkReviewStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("network review \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newNetworkReviewService(_ store: any NetworkReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> NetworkReviewService {
        return NetworkReviewService(
            store: store,
            validator: defaultNetworkReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultNetworkReviewEngine(flags)
        )
    }
}
