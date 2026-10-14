import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves census drafts through their life cycle and keeps a journal of what it did.
    final class CensusDraftService {
        var store: any CensusDraftStore
        var validator: CensusDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CensusDraftEngine

        init(store: any CensusDraftStore, validator: CensusDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CensusDraftEngine) {
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
                throw Kit.Failure("census draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CensusDraftStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CensusDraftStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("census draft \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newCensusDraftService(_ store: any CensusDraftStore, clock: any Kit.Clocks.Clock) -> CensusDraftService {
        return CensusDraftService(
            store: store,
            validator: defaultCensusDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultCensusDraftEngine()
        )
    }
}
