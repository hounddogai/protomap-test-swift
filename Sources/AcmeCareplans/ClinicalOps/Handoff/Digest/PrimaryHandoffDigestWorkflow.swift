import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves primary handoff digests through their life cycle and keeps a journal of what it did.
    final class PrimaryHandoffDigestService {
        var store: any PrimaryHandoffDigestStore
        var validator: PrimaryHandoffDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryHandoffDigestEngine

        init(store: any PrimaryHandoffDigestStore, validator: PrimaryHandoffDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryHandoffDigestEngine) {
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
                throw Kit.Failure("primary handoff digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryHandoffDigestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary handoff digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryHandoffDigestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary handoff digest \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newPrimaryHandoffDigestService(_ store: any PrimaryHandoffDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryHandoffDigestService {
        return PrimaryHandoffDigestService(
            store: store,
            validator: defaultPrimaryHandoffDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryHandoffDigestEngine(flags)
        )
    }
}
