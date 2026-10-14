import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool digests through their life cycle and keeps a journal of what it did.
    final class FloatPoolDigestDesk {
        var store: any FloatPoolDigestStore
        var validator: FloatPoolDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FloatPoolDigestEngine

        init(store: any FloatPoolDigestStore, validator: FloatPoolDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FloatPoolDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolDigestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolDigestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool digest \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newFloatPoolDigestDesk(_ store: any FloatPoolDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FloatPoolDigestDesk {
        return FloatPoolDigestDesk(
            store: store,
            validator: defaultFloatPoolDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultFloatPoolDigestEngine(flags)
        )
    }
}
