import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rolling rounding digests through their life cycle and keeps a journal of what it did.
    final class RollingRoundingDigestService {
        var store: any RollingRoundingDigestStore
        var validator: RollingRoundingDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingRoundingDigestEngine

        init(store: any RollingRoundingDigestStore, validator: RollingRoundingDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingRoundingDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling rounding digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingRoundingDigestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling rounding digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingRoundingDigestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling rounding digest \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newRollingRoundingDigestService(_ store: any RollingRoundingDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingRoundingDigestService {
        return RollingRoundingDigestService(
            store: store,
            validator: defaultRollingRoundingDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingRoundingDigestEngine(flags)
        )
    }
}
