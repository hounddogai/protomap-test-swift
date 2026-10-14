import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves pending program notices through their life cycle and keeps a journal of what it did.
    final class PendingProgramNoticeService {
        var store: any PendingProgramNoticeStore
        var validator: PendingProgramNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingProgramNoticeEngine

        init(store: any PendingProgramNoticeStore, validator: PendingProgramNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingProgramNoticeEngine) {
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
                throw Kit.Failure("pending program notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingProgramNoticeStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending program notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingProgramNoticeStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending program notice \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newPendingProgramNoticeService(_ store: any PendingProgramNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingProgramNoticeService {
        return PendingProgramNoticeService(
            store: store,
            validator: defaultPendingProgramNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingProgramNoticeEngine(flags)
        )
    }
}
