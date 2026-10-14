import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim digests through their life cycle and keeps a journal of what it did.
    final class ClaimDigestService {
        var store: any ClaimDigestStore
        var validator: ClaimDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimDigestEngine

        init(store: any ClaimDigestStore, validator: ClaimDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimDigestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimDigestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim digest \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newClaimDigestService(_ store: any ClaimDigestStore, clock: any Kit.Clocks.Clock) -> ClaimDigestService {
        return ClaimDigestService(
            store: store,
            validator: defaultClaimDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimDigestEngine()
        )
    }
}
